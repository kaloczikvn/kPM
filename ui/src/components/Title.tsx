import React from "react";

import './Title.scss';

interface Props {
    text?: string;
    bottom?: boolean;
}

const Title: React.FC<Props> = ({ text, bottom }) => {
    return (
        <>
            <div className={"header " + (bottom ? 'bottom' : '')}>
                <h1>{text??''}</h1>
            </div>
        </>
    );
};

export default Title;
